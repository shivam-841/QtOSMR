#include <QApplication>
#include <QMainWindow>
#include <QVBoxLayout>
#include <QWidget>
#include <QtQuickWidgets/QQuickWidget>

int main(int argc, char *argv[])
{
    QApplication app(argc, argv);

    QMainWindow mainWindow;
    QWidget *centralWidget = new QWidget();
    QVBoxLayout *layout = new QVBoxLayout(centralWidget);

    QQuickWidget *quickWidget = new QQuickWidget;
    quickWidget->setSource(QUrl("qrc:/MapView.qml"));  // <-- Important
    quickWidget->setResizeMode(QQuickWidget::SizeRootObjectToView);
    layout->addWidget(quickWidget);

    centralWidget->setLayout(layout);
    mainWindow.setCentralWidget(centralWidget);
    mainWindow.resize(800, 600);
    mainWindow.show();

    return app.exec();
}
