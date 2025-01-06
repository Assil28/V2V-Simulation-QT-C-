/********************************************************************************
** Form generated from reading UI file 'mainwindow.ui'
**
** Created by: Qt User Interface Compiler version 6.8.0
**
** WARNING! All changes made in this file will be lost when recompiling UI file!
********************************************************************************/

#ifndef UI_MAINWINDOW_H
#define UI_MAINWINDOW_H

#include <QtCore/QVariant>
#include <QtQuickWidgets/QQuickWidget>
#include <QtWidgets/QApplication>
#include <QtWidgets/QHBoxLayout>
#include <QtWidgets/QLineEdit>
#include <QtWidgets/QListWidget>
#include <QtWidgets/QMainWindow>
#include <QtWidgets/QMenuBar>
#include <QtWidgets/QPushButton>
#include <QtWidgets/QSlider>
#include <QtWidgets/QStatusBar>
#include <QtWidgets/QVBoxLayout>
#include <QtWidgets/QWidget>

QT_BEGIN_NAMESPACE

class Ui_MainWindow
{
public:
    QWidget *centralwidget;
    QQuickWidget *quickWidget_MapView;
    QWidget *horizontalLayoutWidget;
    QHBoxLayout *horizontalLayout;
    QLineEdit *numCars;
    QPushButton *pushButton_2;
    QPushButton *pauseButton;
    QSlider *horizontalSlider;
    QPushButton *pushButton;
    QPushButton *toggleGridButton;
    QPushButton *toggleLogButton;
    QWidget *verticalLayoutWidget;
    QVBoxLayout *verticalLayout;
    QWidget *widget;
    QWidget *panelWidget;
    QListWidget *logListWidget;
    QMenuBar *menubar;
    QStatusBar *statusbar;

    void setupUi(QMainWindow *MainWindow)
    {
        if (MainWindow->objectName().isEmpty())
            MainWindow->setObjectName("MainWindow");
        MainWindow->resize(1451, 765);
        centralwidget = new QWidget(MainWindow);
        centralwidget->setObjectName("centralwidget");
        quickWidget_MapView = new QQuickWidget(centralwidget);
        quickWidget_MapView->setObjectName("quickWidget_MapView");
        quickWidget_MapView->setGeometry(QRect(-60, -20, 1591, 951));
        quickWidget_MapView->setResizeMode(QQuickWidget::ResizeMode::SizeRootObjectToView);
        horizontalLayoutWidget = new QWidget(centralwidget);
        horizontalLayoutWidget->setObjectName("horizontalLayoutWidget");
        horizontalLayoutWidget->setGeometry(QRect(100, 0, 687, 31));
        horizontalLayout = new QHBoxLayout(horizontalLayoutWidget);
        horizontalLayout->setObjectName("horizontalLayout");
        horizontalLayout->setContentsMargins(0, 0, 0, 0);
        numCars = new QLineEdit(horizontalLayoutWidget);
        numCars->setObjectName("numCars");
        numCars->setMaximumSize(QSize(50, 16777215));

        horizontalLayout->addWidget(numCars);

        pushButton_2 = new QPushButton(horizontalLayoutWidget);
        pushButton_2->setObjectName("pushButton_2");

        horizontalLayout->addWidget(pushButton_2);

        pauseButton = new QPushButton(horizontalLayoutWidget);
        pauseButton->setObjectName("pauseButton");

        horizontalLayout->addWidget(pauseButton);

        horizontalSlider = new QSlider(horizontalLayoutWidget);
        horizontalSlider->setObjectName("horizontalSlider");
        horizontalSlider->setOrientation(Qt::Orientation::Horizontal);

        horizontalLayout->addWidget(horizontalSlider);

        pushButton = new QPushButton(horizontalLayoutWidget);
        pushButton->setObjectName("pushButton");

        horizontalLayout->addWidget(pushButton);

        toggleGridButton = new QPushButton(horizontalLayoutWidget);
        toggleGridButton->setObjectName("toggleGridButton");

        horizontalLayout->addWidget(toggleGridButton);

        toggleLogButton = new QPushButton(horizontalLayoutWidget);
        toggleLogButton->setObjectName("toggleLogButton");

        horizontalLayout->addWidget(toggleLogButton);

        verticalLayoutWidget = new QWidget(centralwidget);
        verticalLayoutWidget->setObjectName("verticalLayoutWidget");
        verticalLayoutWidget->setGeometry(QRect(1080, 0, 371, 731));
        verticalLayout = new QVBoxLayout(verticalLayoutWidget);
        verticalLayout->setObjectName("verticalLayout");
        verticalLayout->setContentsMargins(0, 0, 0, 0);
        widget = new QWidget(verticalLayoutWidget);
        widget->setObjectName("widget");
        panelWidget = new QWidget(widget);
        panelWidget->setObjectName("panelWidget");
        panelWidget->setGeometry(QRect(0, -50, 371, 781));
        logListWidget = new QListWidget(panelWidget);
        logListWidget->setObjectName("logListWidget");
        logListWidget->setGeometry(QRect(0, 50, 371, 721));

        verticalLayout->addWidget(widget);

        MainWindow->setCentralWidget(centralwidget);
        menubar = new QMenuBar(MainWindow);
        menubar->setObjectName("menubar");
        menubar->setGeometry(QRect(0, 0, 1451, 26));
        MainWindow->setMenuBar(menubar);
        statusbar = new QStatusBar(MainWindow);
        statusbar->setObjectName("statusbar");
        MainWindow->setStatusBar(statusbar);

        retranslateUi(MainWindow);

        QMetaObject::connectSlotsByName(MainWindow);
    } // setupUi

    void retranslateUi(QMainWindow *MainWindow)
    {
        MainWindow->setWindowTitle(QCoreApplication::translate("MainWindow", "MainWindow", nullptr));
        pushButton_2->setText(QCoreApplication::translate("MainWindow", "D\303\251marrer", nullptr));
        pauseButton->setText(QCoreApplication::translate("MainWindow", "Pause", nullptr));
        pushButton->setText(QCoreApplication::translate("MainWindow", "Nettoyer la map", nullptr));
        toggleGridButton->setText(QCoreApplication::translate("MainWindow", "Afficher/Cacher la Grille", nullptr));
        toggleLogButton->setText(QCoreApplication::translate("MainWindow", "Cacher la Liste", nullptr));
        panelWidget->setStyleSheet(QCoreApplication::translate("MainWindow", "\n"
"                background-color: rgba(0, 0, 0, 180);\n"
"                color: white;\n"
"            ", nullptr));
        logListWidget->setStyleSheet(QCoreApplication::translate("MainWindow", "\n"
"                background-color: rgba(0, 0, 0, 40);  /* Black with transparency */\n"
"                color: white;  /* White text */\n"
"            ", nullptr));
    } // retranslateUi

};

namespace Ui {
    class MainWindow: public Ui_MainWindow {};
} // namespace Ui

QT_END_NAMESPACE

#endif // UI_MAINWINDOW_H
